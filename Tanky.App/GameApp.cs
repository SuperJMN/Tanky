using System;
using System.Reactive.Disposables;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;
using Tanky.App.Actors;

namespace Tanky.App
{
    /// <summary>
    ///     This is the main type for your game.
    /// </summary>
    public class GameApp : Game
    {
        private readonly CompositeDisposable disposables = new CompositeDisposable();
        private readonly GraphicsDeviceManager graphics;
        private readonly KeyboardObserver keyboardObserver = new KeyboardObserver();
        private readonly Actors.Tanky tanky = new Actors.Tanky();
        private SpriteFont font;
        private SpriteBatch spriteBatch;
        private MainStage stage;

        public GameApp()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            graphics.PreferredBackBufferWidth = 720;
            graphics.PreferredBackBufferHeight = 480;
            //graphics.ToggleFullScreen();

            keyboardObserver.KeyDownChanged(Keys.F1).Subscribe(b => tanky.SwitchWeapon()).DisposeWith(disposables);
            keyboardObserver.KeyDownChanged(Keys.Up).Subscribe(isDown =>
            {
                if (tanky.JumpState == JumpState.Jumping)
                {
                    tanky.HaltJump();
                }
            });

            tanky.Died.Subscribe(_ =>
            {
                if (--Lives >= 1)
                {
                    tanky.Respawn();
                }
                else
                {
                    GameOver();
                }
            }).DisposeWith(disposables);
        }

        public int Lives { get; set; } = 3;
        public int Score { get; set; }

        private void GameOver()
        {
        }

        /// <summary>
        ///     Allows the game to perform any initialization it needs to before starting to run.
        ///     This is where it can query for any required services and load any non-graphic
        ///     related content.  Calling base.Initialize will enumerate through any components
        ///     and initialize them as well.
        /// </summary>
        protected override void Initialize()
        {
            base.Initialize();
        }

        /// <summary>
        ///     LoadContent will be called once per game and is the place to load
        ///     all of your content.
        /// </summary>
        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);
            var song = Content.Load<Song>("bgm/ladynavigation");
            MediaPlayer.Play(song);
            MediaPlayer.Volume = 0.25F;
            MediaPlayer.IsRepeating = true;

            stage = new MainStage(Content, graphics.PreferredBackBufferWidth, graphics.PreferredBackBufferHeight);
            OnStageCreated(stage);
            Constants.GroundTop = (float)(graphics.GraphicsDevice.Viewport.Height * (1 - (double)1 / 7));
            font = Content.Load<SpriteFont>("Arial");
        }

        private void OnStageCreated(IStage stage)
        {
            stage.Add(tanky);
        }

        /// <summary>
        ///     UnloadContent will be called once per game and is the place to unload
        ///     game-specific content.
        /// </summary>
        protected override void UnloadContent()
        {
            stage.Dispose();
            disposables.Dispose();
        }

        /// <summary>
        ///     Allows the game to run logic such as updating the world,
        ///     checking for collisions, gathering input, and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
                Keyboard.GetState().IsKeyDown(Keys.Escape))
            {
                Exit();
            }

            if (Lives > 0)
            {
                ProcessPlayerInput(gameTime);
            }

            stage.Update(gameTime);

            base.Update(gameTime);
        }

        private void ProcessPlayerInput(GameTime gameTime)
        {
            var kstate = Keyboard.GetState();
            keyboardObserver.Sample();

            if (kstate.IsKeyDown(Keys.Right))
            {
                tanky.Advance(gameTime.ElapsedGameTime);
            }
            else if (kstate.IsKeyDown(Keys.Left))
            {
                tanky.GoBack(gameTime.ElapsedGameTime);
            }

            if (kstate.IsKeyDown(Keys.Space))
            {
                tanky.ShootRequest();
            }

            if (kstate.IsKeyDown(Keys.Up))
            {
                if (tanky.Animation != TankyAnimation.Jump)
                {
                    tanky.JumpRequest();
                }
            }

            if (kstate.IsKeyUp(Keys.Left) && kstate.IsKeyUp(Keys.Right) && tanky.Animation != TankyAnimation.Jump)
            {
                tanky.StopRequest();
            }
        }

        /// <summary>
        ///     This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            spriteBatch.Begin();
            stage.Draw(spriteBatch);
            DrawInfo();

            if (Lives == 0)
            {
                DrawGameOver();
            }

            spriteBatch.End();

            base.Draw(gameTime);
        }

        private void DrawGameOver()
        {
            var scoreText = $"Game Over";
            var measure = font.MeasureString(scoreText);
            var position = new Vector2((float)(stage.Width - measure.X) / 2, (float)(stage.Height - measure.Y) / 2);
            spriteBatch.DrawString(font, scoreText, position, Color.Red, scale: new Vector2(2,2), effects: SpriteEffects.None, origin: Vector2.Zero, rotation:0F, layerDepth: 0);
        }

        private void DrawInfo()
        {
            spriteBatch.DrawString(font, $"Lives: {Lives}", Vector2.Zero, Color.AliceBlue);
            var scoreText = $"Score: {stage.Score}";
            var measure = font.MeasureString(scoreText);
            var position = new Vector2((float)(stage.Width - measure.X) - 50, 0);
            spriteBatch.DrawString(font, scoreText, position, Color.AliceBlue);
        }
    }
}