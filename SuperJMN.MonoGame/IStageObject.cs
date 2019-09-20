using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame.Common;

namespace SuperJMN.MonoGame
{
    public interface IStageObject : IRectangle
    {
        void Draw(SpriteBatch spriteBatch);


        double VerticalSpeed { get; set; }
        double HorizontalSpeed { get; set; }

        Rectangle Bounds { get; }
        IStage Stage { get; set; }
        
        void LoadContent(ContentManager content);
        void Update(GameTime gameTime);
        void CollideWith(IStageObject other);
        void Initialized();
    }
}