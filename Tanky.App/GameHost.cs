using System;
using System.Reactive;
using System.Reactive.Disposables;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;
using SuperJMN.MonoGame.Common;
using TankyApp.Actors;

namespace TankyApp
{
    public class GameHost
    {
        private readonly CompositeDisposable disposables = new CompositeDisposable();
        private readonly MainStage stage;
        private readonly SpriteFont font;
        private readonly KeyboardObserver keyboardObserver = new KeyboardObserver();
        private readonly ISubject<Unit> exit = new Subject<Unit>();

        public GameHost(ContentManager content, GraphicsDeviceManager graphics)
        {
            var song = content.Load<Song>("bgm/ladynavigation");
            MediaPlayer.Play(song);
            MediaPlayer.Volume = 0.25F;
            MediaPlayer.IsRepeating = true;

            stage = new MainStage(content, graphics.PreferredBackBufferWidth, graphics.PreferredBackBufferHeight)
                .DisposeWith(disposables);
            
            Constants.GroundTop = (float)(graphics.GraphicsDevice.Viewport.Height * (1 - (double)1 / 7));
            font = content.Load<SpriteFont>("Arial");

            keyboardObserver.KeyDownChanged(Keys.F1).Subscribe(b => stage.Tanky.SwitchWeapon()).DisposeWith(disposables);
            keyboardObserver.KeyDownChanged(Keys.Up).Subscribe(isDown =>
            {
                if (stage.Tanky.JumpState == JumpState.Jumping)
                {
                    stage.Tanky.HaltJump();
                }
            });

            stage.Tanky.Died.Subscribe(_ =>
            {
                if (--Lives >= 1)
                {
                    stage.Tanky.Respawn();
                }
            }).DisposeWith(disposables);
        }

        public int Lives { get; set; } = 3;

        public void Update(GameTime gameTime)
        {
            CheckTerminateRequest();

            if (Lives > 0)
            {
                ProcessPlayerInput(gameTime);
            }

            stage.Update(gameTime);
        }

        
        private void ProcessPlayerInput(GameTime gameTime)
        {
            var kstate = Keyboard.GetState();
            keyboardObserver.Sample();

            if (kstate.IsKeyDown(Keys.Right))
            {
                stage.Tanky.Advance(gameTime.ElapsedGameTime);
            }
            else if (kstate.IsKeyDown(Keys.Left))
            {
                stage.Tanky.GoBack(gameTime.ElapsedGameTime);
            }

            if (kstate.IsKeyDown(Keys.Space))
            {
                stage.Tanky.ShootRequest();
            }

            if (kstate.IsKeyDown(Keys.Up))
            {
                if (stage.Tanky.Animation != TankyAnimation.Jump)
                {
                    stage.Tanky.JumpRequest();
                }
            }

            if (kstate.IsKeyUp(Keys.Left) && kstate.IsKeyUp(Keys.Right) && stage.Tanky.Animation != TankyAnimation.Jump)
            {
                stage.Tanky.StopRequest();
            }
        }

        public void Draw(GameTime gameTime, SpriteBatch spriteBatch)
        {
            stage.Draw(spriteBatch);

            DrawInfo(spriteBatch);

            if (Lives == 0)
            {
                DrawGameOver(spriteBatch);
            }
        }

        private void CheckTerminateRequest()
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
                Keyboard.GetState().IsKeyDown(Keys.Escape))
            {
                exit.OnNext(Unit.Default);
            }
        }

        public IObservable<Unit> Exit => exit.AsObservable();

        private void DrawGameOver(SpriteBatch spriteBatch)
        {
            var scoreText = "Game Over";
            var measure = font.MeasureString(scoreText);
            var position = new Vector2((float)(stage.Width - measure.X) / 2, (float)(stage.Height - measure.Y) / 2);
            spriteBatch.DrawString(font, scoreText, position, Color.Red, scale: new Vector2(2,2), effects: SpriteEffects.None, origin: Vector2.Zero, rotation:0F, layerDepth: 0);
        }

        private void DrawInfo(SpriteBatch spriteBatch)
        {
            spriteBatch.DrawString(font, $"Lives: {Lives}", Vector2.Zero, Color.AliceBlue);
            var scoreText = $"Score: {stage.Score}";
            var measure = font.MeasureString(scoreText);
            var position = new Vector2((float)(stage.Width - measure.X) - 50, 0);
            spriteBatch.DrawString(font, scoreText, position, Color.AliceBlue);
        }

        public void Dispose()
        {
            disposables.Dispose();
        }
    }
}